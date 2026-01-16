use std::error::Error;
use std::fs::read_dir;
use std::path::Path;

fn main() -> Result<(), Box<dyn Error>> {
    let path = if Path::new("./common/proto").exists() {
        "./common/proto"
    } else {
        "../common/proto"
    };

    let files = read_dir(path
    )
        .expect("Failed to read directory")
        .map(|dir_entry| {
            dir_entry.expect("Failed to get directory entry")
                .file_name()
                .into_string()
                .expect("Failed to convert OsString to String")
        })
        .collect::<Vec<_>>();

    tonic_prost_build::configure()
        .build_server(true)
        .build_client(true)
        .compile_protos(&files, &[path.to_string()])?;

    Ok(())
}

