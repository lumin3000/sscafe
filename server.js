var ss = require('socketstream');     // Initializes the SS global variable

ss.load();                            // Loads the project files, including the active configuration

ss.start.single();                    // Start the server in single-process mode (required for Cloud9)

ss.redis.connect();