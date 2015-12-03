---
title: Using stack with Ansible
---

I recently started to use [stack](https://github.com/commercialhaskell/stack)
for all of my personal Haskell projects. Stack is a tool to manage the
dependencies of your Haskell projects, and is an alternative to
`cabal-install`. One of the killer features of stack is the ability to download
a pre-built copy of GHC for your platform. This is awesome for continuous
integration setups, and for automated deployments, because it becomes very easy
to install both GHC and your dependencies using one simple tool.

I also use [Ansible](http://www.ansible.com/) to manage my personal server
configurations. Ansible allows you to declaratively specify what you want your
server to look like, in terms of installed packages, open ports, users, etc.
Installing a recent version of GHC on an Ubuntu server with Ansible used to be
a somewhat painful multi-step process. However, with the addition of stack to
the Haskell tool chest, that is no longer so.

In this blog post, I present the *very* simple role I created for installing
stack on an Ubuntu server using Ansible.


# The Task List

Installing stack is surprisingly simple. You just have to:

1. Add the trusted apt keys for the stack deb repo
2. Add the deb repo to your apt sources
3. Install stack using apt-get

That 3 step process is shown in the following list of Ansible tasks:

```yaml
---
- name: Add stack repo keys
  apt_key:
    keyserver: keyserver.ubuntu.com
    id: 575159689BEFB442

- name: Add stack deb repo
  apt_repository: repo="deb http://download.fpcomplete.com/ubuntu/{{ ansible_distribution_release }} stable main"

- name: Install stack
  apt: name=stack
       state=present
```

Note the use of the `ansible_distribution_release` variable, which gives you
the name of the Ubuntu version (for example, 14.04 has a release name of
"trusty").


# Building a Project

If you want to install stack on a server, I assume you want to build projects
with it! If you already have a cabal file and a `stack.yaml` file, then
building a project with stack is a simply two-step process:

1. `stack setup` downloads the correct version of GHC if it is not already
   installed
2. `stack build` builds your project

The following list of tasks is what I used to use to build my personal website
using hakyll (I now just upload the files directly using `scp`, but it is still
a good example):

```yaml
---
- name: Check out git head
  git: repo={{ git_repo }}
       dest={{ repo_location }}

- name: Build website
  shell: stack setup && stack build && stack exec -- jdreaver-site rebuild
  args:
    chdir: "{{ repo_location }}"
  environment:  # Prevent UTF-8 encoding errors
    LANG: "C"
    LC_CTYPE: "en_US.UTF-8"

- name: Symlink _site/ to deploy location
  file: src={{ repo_location }}/_site
        dest={{ deploy_location }}
        state=link
```

# Conclusion

This is a very short blog post, but the reason it is short is because stack has
made it so! I was Googling for ways to install a recent GHC version using
Ansible, and I didn't find a stack-based solution. Therefore, I decided to make
this post. I hope it helps at least one person!
