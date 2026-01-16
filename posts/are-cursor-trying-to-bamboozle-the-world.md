---
date: 2026-01-16
---

# Is Cursor trying to bamboozle the world?

On January 14th 2026, Cursor published a blog post titled "Scaling long-running autonomous coding" (https://cursor.com/blog/scaling-agents)

In the blog post, they talk about their experiements about running "coding agents autonomously for weeks" with the goal of "understand[ing] how far we can push the frontier of agentic coding for projects that typically take human teams months to complete".

They talk about some approaches they tried, why they think those failed, and how to address the difficulties.

Finally they arrived at a point where "This solved most of our coordination problems and let us scale to very large projects without any single agent", which then lead to this:

> To test this system, we pointed it at an ambitious goal: building a web browser from scratch. The agents ran for close to a week, writing over 1 million lines of code across 1,000 files. You can explore the source code on GitHub (https://github.com/wilsonzlin/fastrender)

This is where things get a bit murky and unclear. They claim "Despite the codebase size, new agents can still understand it and make meaningful progress" and "Hundreds of workers run concurrently, pushing to the same branch with minimal conflicts", but they never actually say if this is successful or not, is it actually working?

Then after this, they embed the following video:

[video]

And below it, they say "While it might seem like a simple screenshot, building a browser from scratch is extremely difficult.".

However, here's the bamboozle:

#### They never actually claim this browser is working and functional

And if you try to compile it yourself, you'll see that it's very far away from being a functional browser at all, and seemingly, it never actually was able to build.

I'm not sure what the "agents" they unleashed on this codebase actually did, but they seemingly never ran "cargo build" or even less "cargo check", because both of those commands surface 10s of errors (which surely would balloon should we solve them) and about 100 warnings.

They later start to talk about what's next, but not a single word about how to run it, what to expect, how it's working or anything else.

And diving into the codebase, if the compilation errors didn't make that sure, makes it very clear to any software developer that none of this is actually engineered code. It is what is typically known as "AI slop", low quality *something* that surely represents *something*, but it doesn't have intention behind it, and it doesn't even compile at this point.

They finish of the article saying:

> But the core question, can we scale autonomous coding by throwing more agents at a problem, has a more optimistic answer than we expected.

Which seems like a really strange conclusion to arrive at, when all they've proved so far, is that agents can output millions of tokens and still not end up with something that actually works.
