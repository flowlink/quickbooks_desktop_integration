#!/bin/bash
docker-compose -f docker-compose.yml \
               -f docker-compose.dev.yml \
               run --rm quickbooks-desktop-integration \
               sh -c "AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret AWS_REGION=region bundle exec rspec ${@}"
