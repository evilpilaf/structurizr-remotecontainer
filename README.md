# Structurizr DevContainer

## Description

The goal of this project is to provide anyone wanting to work with the [Structurizr CLI](https://github.com/structurizr/cli) a self-contained environment where they can use it without having to worry about installing the dependencies.

### What's included

-   Alpine Linux v3.13
-   OpenJDK v11
-   Structurizr CLI v1.8.0

## How to use

To begin working with this clone the repository template and start Visual Studio Code, there you'll be prompted to `Open Folder in Container`, after doing this you'll be working within the remote container. Once inside the Structurizr CLI will be part of your `PATH` so you can simply invoke it

Alternatively you can just copy over the contents of the `./devcontainer` folder into your project

### Structurizr CLI

For a complete list of commands for the CLI refer to the official documentation https://github.com/structurizr/cli/blob/master/README.md

## What is a Dev container?

> NOTE: For a complete, and probably better description refer to the official documentation from Microsoft [here](https://code.visualstudio.com/learn/develop-cloud/containers).

Dev containers allows you to have a completely isolated and self-contained environment where all the dependencies you will need for a specific project are already installed and configured and won't clash with anything else you might have installed in your host machine.

## What is Structurizr?

> Structurizr is a collection of tooling to create software architecture diagrams/documentation, and specifically designed to support the C4 model for visualizing software architecture.
>
> &mdash; <cite>[Structurizr website](https://www.structurizr.com/)</cite>
