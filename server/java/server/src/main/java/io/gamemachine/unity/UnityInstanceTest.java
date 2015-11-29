package io.gamemachine.unity;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.gamemachine.core.GameMessageActor;
import io.gamemachine.messages.GameMessage;
import io.gamemachine.messages.UnityInstanceData;

public class UnityInstanceTest extends GameMessageActor {

	private static final Logger log = LoggerFactory.getLogger(UnityInstanceTest.class);
	@Override
	public void awake() {
		UnityInstanceData data = new UnityInstanceData();
		data.scene = "test";
		UnityInstanceManager.requestInstance("test", data);
		
		scheduleOnce(1000l, "tick");
	}

	@Override
	public void onTick(String message) {
		UnityInstance instance = UnityInstanceManager.findByName("test");
		if (instance != null && instance.running) {
			String actorName = "ExampleActor";
			long startTime = System.nanoTime();
			for (int i=0; i<1;i++) {
				GameMessage gameMessage = new GameMessage();
				GameMessage response = instance.ask(gameMessage, actorName);
			}
			
			long endTime = System.nanoTime();
			long duration = (endTime - startTime) / 1000000;  //divide by 1000000 to get milliseconds.
			log.warn("Time "+duration);
		}
		scheduleOnce(1000l, "tick");
	}
	
	@Override
	public void onGameMessage(GameMessage gameMessage) {
		// TODO Auto-generated method stub
		
	}

}