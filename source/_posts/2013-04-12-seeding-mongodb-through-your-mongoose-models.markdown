---
layout: post
title: Seeding mongodb through your mongoose models
tags: Development MongoDB Mongoose Node.js
status: publish
type: post
published: true
comments: true
permalink: /seeding-mongodb-through-your-mongoose-models/
---
**23/4/2013 Update:**
*A change implementing promise support for the* `create` *function [was just committed to GitHub](https://github.com/LearnBoost/mongoose/commit/2ef5f237e054fc4846143530410e353ef7a7456e), and should be available in the 3.7 release of Mongoose. Sweet!*

Just wanted to share a nice little technique I discovered when working on a project using the wonderful [Mongoose](http://mongoosejs.com/) library to interact with a MongoDB database in Node.js. I was writing some integration tests, and needed to reset and seed the database from a set of JSON files before running each test. I really wanted to do this through my existing Mongoose models, so that I could get all the seed data validated before running my tests. Since there also are relations between my different collections I needed to insert the collections in a certain order, so my first attempt quickly devolved into a textbook example of the good ol' pyramid of doom:

{% gist 6033297 %}

In the above code snippet `User`, `Exercise`, and `WorkoutTemplate` are my mongoose models, and since my `WorkoutTemplate` schema references my `Exercise` schema I need to insert data in that specific order. Using Mongoose's `remove` function with an empty object as the first argument will clear everything from the related collection. Furthermore, the `create` function will attempt to do a batch insert of the array you hand it. However, as you can see this quickly devolved into callback hell, and that was with just three different collections! Fortunately, I discovered that the `exec` function, which you can call on query objects, returns a promise object. This means I can just make a pretty, little promise chain instead of using callbacks.

There is just one obstacle to this... The `create` function does not return a query object, meaning we can't call `exec` on it to return a promise... I decided to rectify this by attaching a new function on the base mongoose Model which basically just wraps the `create` function, but actually returns a promise object.

{% gist 6033333 %}

So, finally I am able to create a nice and neat promise chain in the `beforeEach` function of my test suite. Voilà!

{% gist 6033342 %}