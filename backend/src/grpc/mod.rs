mod authentication;

use crate::error::AppResult;
use crate::grpc::authentication::GrpcAuthenticationService;
use crate::grpc::generated::authentication_service_server::AuthenticationServiceServer;
use crate::services::PlayerService;
use std::sync::Arc;
use tonic::transport::Server;

pub mod generated {
    tonic::include_proto!("authentication");
}

pub async fn start_grpc_server(player_service: Arc<PlayerService>) -> AppResult<()> {
    let addr = "0.0.0.0:50051".parse()?;
    let auth_service = GrpcAuthenticationService::new(player_service);

    Server::builder()
        .add_service(AuthenticationServiceServer::new(auth_service))
        .serve(addr)
        .await?;

    Ok(())
}