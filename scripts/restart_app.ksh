#!/bin/ksh
#Script for stopping the application

echo "Stop application."
$APPLICATION_HOME/app_script stop

echo "Waiting for 60 seconds..."
sleep 60

echo "Start application" 
$APPLICATION_HOME/app_script start