#!/bin/bash

cd ..

echo Installing bundler gem...
gem install bundler

echo Install application specific gems using bundler...
bundle install --gemfile=Gemfile
