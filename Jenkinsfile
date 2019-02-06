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
    docker.image('qixxit/elixir-centos').inside('-u root -e MIX_ENV=prod') {
      sh 'mix deps.get'
      sh 'mix release'
      sh 'cp _build/prod/rel/origin_simulator/releases/*/origin_simulator.tar.gz SOURCES/'
      sh 'rm -rf _build'
    }
  }
  BBCNews.archiveDirectoryAsPackageSource('bake-scripts', 'bake-scripts.tar.gz')
  BBCNews.buildRPMWithMock(cosmosService, 'origin-simulator.spec', params.FORCE_RELEASE)
  BBCNews.setRepositories(cosmosService, 'repositories.json')
  BBCNews.cosmosRelease(cosmosService, 'RPMS/*.x86_64.rpm', params.FORCE_RELEASE)
}