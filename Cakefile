fs = require 'fs'
{exec} = require 'child_process'

config =
  packageJson:
    name: 'socketmoor'
    author: 'Paul Nechifor <paul@nechifor.net>'
    version: '0.0.1'
    private: false
    dependencies:
      ws: '>=0.4.30'
    main: './lib'
    repository:
      type: 'git'
      url: 'https://github.com/paul-nechifor/web-build-tools'
    license: 'MIT'

sh = (commands, cb) ->
  exec commands, (err, stdout, stderr) ->
    throw err if err
    out = stdout + stderr
    console.log out if out.length > 0
    cb()

cleanupLib = (cb) ->
  sh 'rm -fr lib/; mkdir lib', cb

writePackage = ->
  json = JSON.stringify config.packageJson, null, '  '
  fs.writeFileSync 'package.json', json

compile = (cb) ->
  sh 'coffee --compile --bare --output lib src', cb

task 'build', 'Build the Node package.', ->
  cleanupLib ->
    writePackage()
    compile ->
