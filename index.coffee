util = require 'util'
EventEmiter = require('events').EventEmitter
MongoClient = require('mongodb').MongoClient

module.exports = class ReplicationLagPlugin extends EventEmiter
	constructor: (@config) ->
		@criticalCounter = 0
		@warningCounter = 0
		@maxCriticalCounterValue = 5
		@actualDelay = 0
		@enabled = yes

	getPluginName: () ->
		return "ReplicationLagPlugin"
	open: () ->
		MongoClient.connect @config.url, (error, @client) =>
			if error
				@emit 'error', error
			@emit 'ready'
			@check()

	stop: () ->
		@enabled = no

	close: () ->
		@stop()
		if @client
			@client.close (error)=>
				if error
					@emit 'error', error

	check: () =>
		cmd = {'replSetGetStatus'}
		@client.command cmd, (err,result) =>
			if err
				throw err
			slavesOptime=[]
			for server in result.members
				if server.state is 1
					masterOptime = server.optime.high_
				else
					slavesOptime.push {name: server.name, optime: server.optime.high_}
			newValue=[]
			for slave in slavesOptime
				delay = parseInt(masterOptime)-parseInt(slave.optime)
				newValue.push {name: slave.name, value:delay}
				if delay >= @config.criticalLevel
					@criticalCounter++
					@emit 'critical', delay, @criticalCounter, slave.name
				else
					@criticalCounter = 0
				if delay >= @config.warningLevel
					@warningCounter++
					@emit 'warning', delay, @warningCounter, slave.name
				else @warningCounter = 0
			@emit 'new-value', newValue

			c=()=>
				@check()
			delay=parseInt(@config.sleepTime)*1000;
			setTimeout(c, delay) if @enabled is yes



