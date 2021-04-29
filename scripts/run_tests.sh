#!/bin/bash
docker-compose run --rm quickbooks-desktop-integration \
               sh -c "AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret AWS_REGION=us-east-1 bundle exec rspec ${@}"
