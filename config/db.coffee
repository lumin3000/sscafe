# Place your Database config here
config = SS.config.db.development
mongoose = require 'mongoose'
global.db = mongoose.connect "mongodb://#{config.host}/#{config.database}"
