---
layout: post
title: Application Cache Update Process State Diagram
tags: Application Cache Development
status: publish
type: post
published: true
comments: true
permalink: /application-cache-update-process-state-diagram/
---
Here's a quick  little follow-up to my last post about the Application Cache. How the browser checks and fetches the cache can be a little confusing at first, so I made a state diagram to keep track of the different states the Application Cache might be in and the events that change said state.

{% img /images/posts/appCache_stateDiag.png %}

Well, it's not awfully complicated, but it's nice to have a visual aid when debugging. The guard conditions indicate whether there already exists an old version of the application cache or not.
