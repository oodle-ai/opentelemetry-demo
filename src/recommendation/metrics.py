#!/usr/bin/python

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

def init_metrics(meter, cache_size_callback=None):

    # Recommendations counter
    app_recommendations_counter = meter.create_counter(
        'app_recommendations_counter', unit='recommendations', description="Counts the total number of given recommendations"
    )

    # Cache size gauge - observable gauge that reports current cache size
    app_recommendations_cache_size = None
    if cache_size_callback:
        app_recommendations_cache_size = meter.create_observable_gauge(
            'app_recommendations_cache_size', 
            callbacks=[cache_size_callback],
            unit='items', 
            description="Current size of the recommendation cache"
        )

    rec_svc_metrics = {
        "app_recommendations_counter": app_recommendations_counter,
        "app_recommendations_cache_size": app_recommendations_cache_size,
    }

    return rec_svc_metrics
