Plugin = require './index'
util = require 'util'

config=
	url:"<<<<mongodb connection string>>>>>"
	warningLevel: 10
	criticalLevel: 50
	sleepTime: 5


mongoPlugin = new Plugin config


mongoPlugin.on 'error', (error) ->
	util.log "Something went wrong in mongodb plugin"
	util.log util.inspect error


mongoPlugin.on 'warning', (delay,cnt,hostname)->
	util.log "WARNING LEVEL - #{delay}s on #{hostname}!"

mongoPlugin.on 'critical', (delay,cnt, hostname)->
	util.log "CRITICAL LEVEL - #{delay}s on #{hostname}!"

cnt=0
mongoPlugin.on 'new-value', (data)->
	for value in data
		util.log "Delay from #{value.host} are #{value.delay} seconds"
	
	if cnt++ > 10
		mongoPlugin.close()


mongoPlugin.open()

