#!/usr/bin/python

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

def init_metrics(meter):
    """
    Initialize metrics for the recommendation service.
    
    Args:
        meter: OpenTelemetry meter instance
    """

    # Recommendations counter
    app_recommendations_counter = meter.create_counter(
        'app_recommendations_counter', unit='recommendations', description="Counts the total number of given recommendations"
    )

    # Cache size histogram - tracks the current size of the recommendation cache
    # Using Histogram to record cache size values, which allows tracking current value and distribution
    app_recommendation_cache_size = meter.create_histogram(
        'app_recommendation_cache_size', 
        unit='items', 
        description="Current size of the recommendation cache in number of items"
    )

    rec_svc_metrics = {
        "app_recommendations_counter": app_recommendations_counter,
        "app_recommendation_cache_size": app_recommendation_cache_size,
    }

    return rec_svc_metrics
