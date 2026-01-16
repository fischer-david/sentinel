use std::error::Error;
use std::path::Path;

fn main() -> Result<(), Box<dyn Error>> {
    let path = if Path::new("./common/proto").exists() {
        "./common/proto"
    } else {
        "../common/proto"
    };

    tonic_prost_build::configure()
        .build_server(true)
        .build_client(true)
        .compile_protos(&[format!("{path}/authentication.proto")], &[path.to_string()])?;

    Ok(())
}

