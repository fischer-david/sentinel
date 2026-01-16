use crate::grpc::generated::report_service_server::ReportService as GeneratedReportService;
use crate::services::ReportService;
use std::sync::Arc;

pub struct GrpcReportService {
    report_service: Arc<ReportService>
}

impl GrpcReportService {
    pub fn new(report_service: Arc<ReportService>) -> Self {
        Self {
            report_service
        }
    }
}

#[tonic::async_trait]
impl GeneratedReportService for GrpcReportService {

}