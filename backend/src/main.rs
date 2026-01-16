mod database;
mod error;
mod grpc;
mod models;
mod services;

use crate::database::connect_to_db;
use crate::grpc::start_grpc_server;
use crate::services::PlayerService;
use std::sync::Arc;
use tokio::main;

#[main]
async fn main() {
    #[cfg(debug_assertions)]
    dotenvy::dotenv().expect("Failed to load .env file");

    let pg_pool = Arc::new(connect_to_db().await.expect("failed to connect to db"));
    let player_service = Arc::new(PlayerService::new((*pg_pool).clone()));

    let grpc_server = start_grpc_server(player_service.clone());

    tokio::try_join!(grpc_server).expect("Server error");
}
