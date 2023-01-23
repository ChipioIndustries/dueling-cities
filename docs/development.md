# Development

This document covers the structure of the project files and how to work with the tools you've installed. It assumes you've completed the [development environment setup](dev-env).

## Project Files

Most of the top-level project files are configuration files that won't need to be changed. The majority of work will be done in `src/` and `docs/`.

	.github					# Processes that run automatically when changes are made to the repository.
	docs/					# Documentation site content.
		img  				# Images for display on the documentation site.
	src/					# Container for all game code.
		client				# Game code that is stored and runs on the client.
		server				# Game code that is stored and runs on the server.
		shared				# Game code that is shared between the server and client and runs on either or both.
	.gitignore				# Names of temporary files that should not be uploaded to the git repository.
	LICENSE					# Open-source software license that allows the project to be read and used by other folks.
	aftman.toml				# List of tools to be automatically installed by Aftman.
	default.project.json	# Config file that describes to Rojo how to turn the src folder into a Roblox project file
	mkdocs.yml				# Config file for the documentation site
	requirements.txt		# Config file for the documentation site
	selene.toml				# Config file for the linter
	testez.toml 			# Config file to make linter compatible with the unit testing framework
	wally.exe				# Custom build of package manager that fixes a critical bug
	wally.toml				# List of packages for Wally to install automatically

WIP

## Installing and Using Packages with Wally

## Connecting to Roblox Studio

## Making Changes

