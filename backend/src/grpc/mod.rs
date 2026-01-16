mod authentication;
mod report;
mod punishment;

use crate::error::AppResult;
use crate::grpc::authentication::GrpcAuthenticationService;
use crate::grpc::generated::authentication_service_server::AuthenticationServiceServer;
use crate::grpc::generated::punishment_service_server::PunishmentServiceServer;
use crate::grpc::generated::report_service_server::ReportServiceServer;
use crate::grpc::punishment::GrpcPunishmentService;
use crate::grpc::report::GrpcReportService;
use crate::services::{PlayerService, PunishmentService, ReportService};
use std::sync::Arc;
use tonic::transport::Server;

pub mod generated {
    tonic::include_proto!("authentication");
    tonic::include_proto!("punishment");
    tonic::include_proto!("report");
}

pub async fn start_grpc_server(player_service: Arc<PlayerService>,
                               punishment_service: Arc<PunishmentService>,
                               report_service: Arc<ReportService>) -> AppResult<()> {
    let addr = "0.0.0.0:50051".parse()?;
    let grpc_auth_service = GrpcAuthenticationService::new(player_service);
    let grpc_punishment_service = GrpcPunishmentService::new(punishment_service);
    let grpc_report_service = GrpcReportService::new(report_service);

    Server::builder()
        .add_service(AuthenticationServiceServer::new(grpc_auth_service))
        .add_service(PunishmentServiceServer::new(grpc_punishment_service))
        .add_service(ReportServiceServer::new(grpc_report_service))
        .serve(addr)
        .await?;

    Ok(())
}