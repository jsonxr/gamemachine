package io.gamemachine.core;

import akka.actor.DeadLetter;
import akka.actor.UntypedActor;
import akka.event.Logging;
import akka.event.LoggingAdapter;

public class EventStreamHandler extends UntypedActor {

    LoggingAdapter log = Logging.getLogger(getContext().system(), this);

    public EventStreamHandler() {
        this.getContext().system().eventStream().subscribe(this.getSelf(), DeadLetter.class);
        // new DistributedPubSubMediator.Publish("test","out");
        // if (this.getContext().system().name().equals("cluster")) {
        // // ComponentAdd subscription of cluster events
        // Cluster.get(this.getContext().system()).subscribe(getSelf(),
        // ClusterDomainEvent.class);
        // log.info("Subscribing to cluster events");
        // }

    }

    @Override
    public void onReceive(Object message) throws Exception {
        if (message instanceof DeadLetter) {
            DeadLetter letter = (DeadLetter) message;
            // log.warning("DeadLetter " + letter.message() + " " +
            // letter.sender().toString() + " " +
            // letter.recipient().toString());
            // Scala creates bad class names that blow up in jruby and show up
            // in dead letters.
            // ActorSelection sel = ActorUtil
            // .getSelectionByName("GameMachine::SystemMonitor");
            // sel.tell(letter.message(), this.getSelf());
        }

    }
}
