use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::broadcast::error::SendError;
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Clone)]
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