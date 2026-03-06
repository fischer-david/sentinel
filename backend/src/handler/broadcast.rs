use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::broadcast::error::SendError;
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Clone, Debug)]
pub struct KeyValue<T1, T2> {
    pub key: T1,
    pub value: T2,
}

#[derive(Clone)]
pub struct BroadcastHandler<TK, TV> {
    listeners: Arc<RwLock<HashMap<String, (Sender<KeyValue<TK, TV>>, Vec<TK>)>>>,
}

impl<TK: Clone + PartialEq, TV: Clone> BroadcastHandler<TK, TV> {
    pub fn new() -> Self {
        Self {
            listeners: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn start_broadcast_listener(&self, identifier: &Uuid) -> Receiver<KeyValue<TK, TV>> {
        let identifier_str = identifier.to_string();
        let (tx, rx) = channel::<KeyValue<TK, TV>>(100);

        let mut listeners = self.listeners.write().await;
        listeners.insert(identifier_str, (tx, Vec::new()));

        rx
    }

    pub async fn send_event(&self, key: TK, value: TV) -> Result<(), SendError<KeyValue<TK, TV>>> {
        let listeners = self.listeners.read().await;
        let event = KeyValue { key: key.clone(), value };

        listeners.values().filter(|(_, keys)| keys.contains(&key)).for_each(|(sender, _)| {
            let _ = sender.send(event.clone());
        });

        Ok(())
    }

    pub async fn remove_listener(&self, identifier: &Uuid) {
        let mut listeners = self.listeners.write().await;
        listeners.remove(&identifier.to_string());
    }

    pub async fn add_key_to_listener(&self, identifier: &Uuid, key: TK) {
        let mut listeners = self.listeners.write().await;
        let identifier_str = identifier.to_string();
        if let Some((_, keys)) = listeners.get_mut(&identifier_str) {
            keys.push(key);
        }
    }

    pub async fn remove_key_from_listener(&self, identifier: &Uuid, key: TK) {
        let mut listeners = self.listeners.write().await;
        let identifier_str = identifier.to_string();
        if let Some((_, keys)) = listeners.get_mut(&identifier_str) {
            keys.retain(|k| k != &key);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── KeyValue ─────────────────────────────────────────────────────────────

    #[test]
    fn key_value_clone() {
        let kv: KeyValue<u32, String> = KeyValue { key: 42, value: "hello".to_string() };
        let cloned = kv.clone();
        assert_eq!(cloned.key, 42);
        assert_eq!(cloned.value, "hello");
    }

    // ── BroadcastHandler ─────────────────────────────────────────────────────

    #[tokio::test]
    async fn start_listener_and_receive_event() {
        let handler: BroadcastHandler<u32, String> = BroadcastHandler::new();
        let id = Uuid::new_v4();

        let mut rx = handler.start_broadcast_listener(&id).await;

        // Register key 1 for this listener.
        handler.add_key_to_listener(&id, 1u32).await;

        // Send an event for key 1 — should arrive.
        handler.send_event(1u32, "fired".to_string()).await.unwrap();

        let received = rx.recv().await.expect("should receive event");
        assert_eq!(received.key, 1u32);
        assert_eq!(received.value, "fired");
    }

    #[tokio::test]
    async fn event_not_received_for_unregistered_key() {
        let handler: BroadcastHandler<u32, String> = BroadcastHandler::new();
        let id = Uuid::new_v4();

        let mut rx = handler.start_broadcast_listener(&id).await;
        handler.add_key_to_listener(&id, 1u32).await;

        // Send event for key 2 — listener only subscribed to key 1.
        handler.send_event(2u32, "should not arrive".to_string()).await.unwrap();

        // There should be no message waiting — verify channel is empty.
        assert!(rx.try_recv().is_err(), "should not receive event for unregistered key");
    }

    #[tokio::test]
    async fn add_and_remove_key() {
        let handler: BroadcastHandler<u32, String> = BroadcastHandler::new();
        let id = Uuid::new_v4();

        let mut rx = handler.start_broadcast_listener(&id).await;
        handler.add_key_to_listener(&id, 99u32).await;
        handler.remove_key_from_listener(&id, 99u32).await;

        // After removal, events for that key should not be received.
        handler.send_event(99u32, "ghost".to_string()).await.unwrap();
        assert!(rx.try_recv().is_err(), "should not receive event after key removal");
    }

    #[tokio::test]
    async fn remove_listener_drops_sender() {
        let handler: BroadcastHandler<u32, String> = BroadcastHandler::new();
        let id = Uuid::new_v4();

        handler.start_broadcast_listener(&id).await;
        handler.remove_listener(&id).await;

        // After removal, the listener map should be empty.
        let listeners = handler.listeners.read().await;
        assert!(!listeners.contains_key(&id.to_string()));
    }

    #[tokio::test]
    async fn multiple_listeners_each_receive_their_keys() {
        let handler: BroadcastHandler<u32, String> = BroadcastHandler::new();
        let id_a = Uuid::new_v4();
        let id_b = Uuid::new_v4();

        let mut rx_a = handler.start_broadcast_listener(&id_a).await;
        let mut rx_b = handler.start_broadcast_listener(&id_b).await;

        handler.add_key_to_listener(&id_a, 1u32).await;
        handler.add_key_to_listener(&id_b, 2u32).await;

        // Fire event for key 1 — only A should get it.
        handler.send_event(1u32, "for_a".to_string()).await.unwrap();
        assert_eq!(rx_a.recv().await.unwrap().value, "for_a");
        assert!(rx_b.try_recv().is_err());

        // Fire event for key 2 — only B should get it.
        handler.send_event(2u32, "for_b".to_string()).await.unwrap();
        assert_eq!(rx_b.recv().await.unwrap().value, "for_b");
        assert!(rx_a.try_recv().is_err());
    }
}

