/*
	runs `cmake` on every file edit. 
	To help maintain a compile_commands.jsom

    start:
		SOURCE_DIR={} BINARY_DIR={} OPTIONS={cmake options} npm run
*/

const chokidar = require( 'chokidar' );
const exec = require( 'child_process' ).exec;

const source_dir = process.env['SOURCE_DIR'];
const binary_dir = process.env['BINARY_DIR'];
const options = process.env['OPTIONS'];

if ( source_dir == null )
{
	console.log( "missing SOURCE_DIR" );
	process.exit( 1 );
}
if ( binary_dir == null )
{
	console.log( "missing BINARY_DIR" );
	process.exit( 1 );
}

const watcher = chokidar.watch(
	`${source_dir}/**`,
	{ persistent: true }
);

var inProgress = false;

watcher.on( 'all',
	() =>
	{
		if ( inProgress )
			return;
		
		inProgress = true;
		setTimeout(
			() =>
			{
				var cmd = 'cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug';
				if ( options )
				{
					cmd += ` ${options}`;
				}
				cmd += ` ${source_dir}`;
				console.log( cmd );
				var cmake = exec( cmd, { cwd: binary_dir } );
				cmake.stdout.pipe( process.stdout );
				inProgress = false;
			}, 100
		);
	}
);
