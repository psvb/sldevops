@echo off

cd ..

call gem install bundler

call bundle install --gemfile=Gemfile

pause