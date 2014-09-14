module GameMachine
  class Application

    class << self

      def initialize!()
        AppConfig.instance.load_config
        akka.initialize!
      end

      def auth_handler
        AuthHandlers::Base.instance
      end

      def data_store
        DataStore.instance
      end

      def akka
        Akka.instance
      end

      def config
        @config ||= AppConfig.instance.config
      end

      def registered
        @@registered ||= Set.new
      end

      def register(system_class)
        registered << system_class
        GameMachine.logger.debug "#{system_class} registered"
      end

      def start_actor_system
        akka.start
      end

      def stop_actor_system
        akka.stop
      end

      def stop
        stop_actor_system
        DataStore.instance.shutdown
      end

      def start
        create_grids

        unless GameMachine.env == 'test'
          GameMachine::Actor::Reloadable.update_paths(true)
        end

        start_actor_system
        data_store
        orm_connect
        start_endpoints
        start_core_systems
        start_handlers

        if GameMachine.env == 'development'
          start_development_systems
        end

        start_game_systems

        load_games
        
        auth_handler
        start_mono

        GameMachine.logger.info("Game Machine start successful")
        
        # This call blocks, make it the last thing we do
        if config.http.enabled
          #Endpoints::Http::Server.start
          Thread.new do
            start_http
          end
        end
      end

      def orm_connect
        if config.orm
          pool = GameMachine::JavaLib::DbConnectionPool.getInstance
          unless pool.connect(
            'game_machine_orm',
            config.jdbc.hostname,
            config.jdbc.port,
            config.jdbc.database,
            config.jdbc.ds,
            config.jdbc.username,
            config.jdbc.password || ''
          )
            GameMachine.logger.error "Unable to establish database connection, exiting"
            System.exit 1
          end
        end
      end

      def create_grids
        Grid.load_from_config
      end

      def load_games
        begin
          require_relative '../../games/routes.rb'
          require_relative '../../games/boot.rb'
        rescue LoadError => e
          GameMachine.logger.info "Unable to load game files"
        end
      end

      def start_http
        require_relative '../../web/app'
      end

      def start_mono
        if config.mono_enabled
          GameMachine.logger.info "Starting mono server"
          MonoServer.new.run!
        end
      end

      def start_endpoints
        if config.tcp.enabled
          JavaLib::TcpServer.start(config.tcp.host, config.tcp.port);
          GameMachine.logger.info(
            "Tcp starting on #{config.tcp.host}:#{config.tcp.port}"
          )
        end

        if config.udp.enabled
          JavaLib::UdpServer.start(config.udp.host,config.udp.port)
          Actor::Builder.new(Endpoints::UdpIncoming).with_router(
            JavaLib::RoundRobinRouter,config.routers.udp).start
        end
      end

      def start_handlers
        Actor::Builder.new(Handlers::Request).with_router(
          JavaLib::RoundRobinRouter,config.routers.request_handler
        ).start
        Actor::Builder.new(Handlers::Game).with_router(
          JavaLib::RoundRobinRouter,config.routers.game_handler
        ).start
      end

      def start_development_systems
      end

      # TODO configurize router sizes
      def start_core_systems
        JavaLib::GameMachineLoader.StartMessageGateway
        Actor::Builder.new(ClusterMonitor).start
        Actor::Builder.new(ObjectDb).distributed(config.routers.objectdb).start
        Actor::Builder.new(MessageQueue).start
        Actor::Builder.new(SystemMonitor).start
        Actor::Builder.new(ReloadableMonitor).start
        Actor::Builder.new(Scheduler).start
        Actor::Builder.new(WriteBehindCache).distributed(config.routers.objectdb).start
        Actor::Builder.new(ClientManager).start
        Actor::Builder.new(SystemStats).start
        Actor::Builder.new(GameSystems::RemoteEcho).with_router(JavaLib::RoundRobinRouter,config.routers.game_handler).start

        if config.use_regions
          # Our cluster singleton for managing regions
          Actor::Builder.new(GameSystems::RegionManager).singleton

          # Hands out current region info to clients/other actors
          Actor::Builder.new(GameSystems::RegionService).start
        end

        if ENV.has_key?('RESTARTABLE')
          GameMachine.logger.info "restartable=true.  Will respond to tmp/gm_restart.txt"
          Actor::Builder.new(RestartWatcher).start
        end
      end

      def start_game_systems
        Actor::Builder.new(GameSystems::Devnull).start#.with_router(JavaLib::RoundRobinRouter,4).start
        Actor::Builder.new(GameSystems::ObjectDbProxy).with_router(JavaLib::RoundRobinRouter,2).start
        JavaLib::GameMachineLoader.StartEntityTracking
        Actor::Builder.new(GameSystems::LocalEcho).with_router(JavaLib::RoundRobinRouter,1).start
        Actor::Builder.new(GameSystems::LocalEcho).with_name('DistributedLocalEcho').distributed(2).start
        Actor::Builder.new(GameSystems::StressTest).with_router(JavaLib::RoundRobinRouter,1).start
        Actor::Builder.new(GameSystems::ChatManager).start
        Actor::Builder.new(GameSystems::TeamManager).start
        Actor::Builder.new(GameSystems::JsonModelPersistence).start
      end

    end
  end
end
