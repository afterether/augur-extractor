## Augur Data Extractor

Extracts data from Augur Prediction Marketplace (http://augur.net) and stores it in an SQL database.

### Dependencies

 * Latest golang `crypto` package containing `NewLegacyKeccak256` function
 * Latest Ethereum `go-ethereum` package with Tuple ABI Unpack function (v1.9.13)
 * PostgreSQL libpq package

### Build

	./auto-build.sh

This will download all the dependencies and try to build everything

### Running

There are 3 executables to run:

 * etl
 * server
 * mesh

 1.

	cd etl/mesh
	. config/dev-config.env
	./mesh

 2.

	cd etl
	. config/dev-config.env
	./run.sh

3.

	cd server
	. config/dev-config.env
	./run.sh

Once all the 3 programs run, the error logs will be in /var/tmp

### Database initialization

	sql/reset-db.sh

### Database Schema and documentation

	cat etl/sql/tables.sql
