use jsonwebtoken::errors::Error as JwtError;
use serde_json::Error as SerdeJsonError;
use sqlx::Error as SqlxError;
use std::io::Error as IoError;
use std::net::AddrParseError;
use std::result::Result as StdResult;
use thiserror::Error;
use tonic::transport::Error as TonicTransportError;
use uuid::Error as UuidError;
use validator::ValidationErrors;

#[derive(Debug, Error)]
pub enum Error {
    #[error(transparent)]
    SerdeJsonError(#[from] SerdeJsonError),
    #[error(transparent)]
    IoError(#[from] IoError),
    #[error(transparent)]
    SqlxError(#[from] SqlxError),
    #[error(transparent)]
    JwtError(#[from] JwtError),
    #[error(transparent)]
    ValidationError(#[from] ValidationErrors),
    #[error(transparent)]
    TonicTransportError(#[from] TonicTransportError),
    #[error(transparent)]
    AddrParseError(#[from] AddrParseError),
    #[error(transparent)]
    UuidError(#[from] UuidError),

    #[error("You are unauthorized")]
    Unauthorized,

    #[error("wrong credentials")]
    WrongCredentials,
    #[error("Not found")]
    NotFound,
    #[error("Validation failed: {0}")]
    CustomValidationError(String),
    #[error("Internal server error: {0}")]
    InternalError(String),
}

pub type AppResult<T> = StdResult<T, Error>;