#!/usr/bin/python

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

def init_metrics(meter, cache_size_callback=None):

    # Recommendations counter
    app_recommendations_counter = meter.create_counter(
        'app_recommendations_counter', unit='recommendations', description="Counts the total number of given recommendations"
    )

    # Cache size gauge - observable gauge to track current cache size
    app_recommendation_cache_size = None
    if cache_size_callback:
        app_recommendation_cache_size = meter.create_observable_gauge(
            'app_recommendation_cache_size', 
            unit='items', 
            description="Current number of items in the recommendation cache",
            callbacks=[cache_size_callback]
        )

    rec_svc_metrics = {
        "app_recommendations_counter": app_recommendations_counter,
    }
    
    if app_recommendation_cache_size:
        rec_svc_metrics["app_recommendation_cache_size"] = app_recommendation_cache_size

    return rec_svc_metrics
