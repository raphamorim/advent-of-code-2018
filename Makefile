setup:
	@rustup component add rustfmt
	@rustup component add clippy
	@cargo install grcov
	@echo "Install lcov using your package manager of choice"
	@type -p pre-commit >/dev/null 2>&1 || \
		(echo "Please install pre-commit and try again"; exit 1)
	@pre-commit install -f --hook-type pre-commit
	@pre-commit install -f --hook-type pre-push

fmt:
	@pwd
	@cargo fmt -- --verbose

clippy:
	@cargo clippy --all --all-targets --all-features --bins --examples --tests -- -D warnings

lint: fmt clippy

test:
	@rm -rf target
	@cargo test -vv

coverage: export CARGO_INCREMENTAL := 0
coverage: export RUSTFLAGS := -Zprofile -Ccodegen-units=1 -Copt-level=0 \
	-Clink-dead-code -Coverflow-checks=off -Zpanic_abort_tests -Cpanic=abort
coverage: export RUSTDOCFLAGS := -Cpanic=abort
coverage:
	@rm -rf target
	@cargo build
	@cargo test
	@grcov ./target/debug/ -s . -t html --llvm --branch --ignore-not-existing \
		-o ./target/debug/grcov/
	@grcov ./target/debug/ -s . -t lcov --llvm --branch --ignore-not-existing \
		-o ./target/debug/lcov.info
	@lcov -e ./target/debug/lcov.info 'src/*' > ./target/debug/lcov.src.info
	@genhtml -o ./target/debug/lcov/ --show-details --highlight \
		--ignore-errors source --legend ./target/debug/lcov.src.info > /dev/null
	@echo "grcov: file://$$(pwd)/target/debug/grcov/src/index.html"
	@echo "lcov: file://$$(pwd)/target/debug/lcov/src/index.html"
