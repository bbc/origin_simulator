#!/usr/bin/env groovy

library 'devops-tools-jenkins'

def dockerRegistry = libraryResource('dockerregistry').trim()
def dockerImage = "${dockerRegistry}/bbc-news/elixir-centos7:1.11.3"

library 'BBCNews'

def cosmosServices = [
    'origin-simulator',
    'origin-simulator-data-pres',
    'origin-simulator-fabl'
]

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
    docker.image(dockerImage).inside('-u root -e MIX_ENV=prod -e PORT=8080') {
      sh 'elixir --version'
      sh 'mix deps.get'
      sh 'mix release'
    }
  
    sh 'ls _build/prod/rel/origin_simulator/releases/*'
    sh 'cp _build/prod/rel/origin_simulator/releases/*/origin_simulator.tar.gz SOURCES/'
  }

  BBCNews.buildRPMWithMock(cosmosServices.first(), 'origin-simulator.spec', params.FORCE_RELEASE)

  cosmosServices.each { service ->
    BBCNews.setRepositories(service, 'repositories.json')
    BBCNews.cosmosRelease(service, 'RPMS/*.x86_64.rpm', params.FORCE_RELEASE)
  }
}
