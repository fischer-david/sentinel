mkdir -p src/generated

grpc_tools_node_protoc \
    --plugin=protoc-gen-ts=./node_modules/.bin/protoc-gen-ts \
    --ts_out=grpc_js:src/generated \
    --js_out=import_style=commonjs:src/generated \
    --grpc_out=grpc_js:src/generated \
    --proto_path=../common/proto \
    ../common/proto/authentication.proto

echo "Proto client code generated in src/generated/"
