#!/usr/bin/env groovy

library 'BBCNews'

String cosmosService = 'origin-simulator'

node {
  cleanWs()
  checkout scm

  properties([
      disableConcurrentBuilds(),
      parameters([
          booleanParam(defaultValue: false, description: 'Force release from non-master branch', name: 'FORCE_RELEASE')
      ])
  ])

  stage('Build executable') {
    sh 'mkdir -p SOURCES'
    docker.image('elixir:1.8.1').inside('-u root -e MIX_ENV=prod') {
      sh 'mix local.hex --force'
      sh 'mix deps.get'
      sh 'mix local.rebar --force'
      sh 'mix release'
      sh 'cp _build/prod/rel/origin_simulator/releases/*/origin_simulator.tar.gz SOURCES/'
      sh 'rm -rf _build'
    }
  }
  BBCNews.buildRPMWithMock(cosmosService, 'origin-simulator.spec', params.FORCE_RELEASE)
  BBCNews.setRepositories(cosmosService, 'repositories.json')
  BBCNews.cosmosRelease(cosmosService, 'RPMS/*.x86_64.rpm', params.FORCE_RELEASE)
}