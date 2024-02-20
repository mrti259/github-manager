import { GithubClient } from "./github-client.imba"

global css
	.capitalize tt:capitalize

tag app
	visibilityOptions = ["all", "public", "private"]
	affiliationOptions = ["owner", "collaborator", "organization_member"]
	sortOptions = ["created", "updated", "pushed", "full_name"]
	directionOptions = ["asc", "desc"]
	pageOptions = [1]
	perPageOptions = [10, 20, 50]
	actionOptions = {
		privateRepos:
			type: "repos"
			description: "Set to private"
			filter: do(repo) !repo.private
			call: do(repo) client.updateRepo repo, {private: yes}
		publicRepos:
			type: "repos"
			description: "Set to public"
			filter: do(repo) repo.private
			call: do(repo) client.updateRepo repo, {private: no}
		archiveRepos:
			type: "repos"
			description: "Archive"
			filter: do(repo) !repo.archived
			call: do(repo) client.updateRepo repo, {archived: yes}
		unarchiveRepos:
			type: "repos"
			description: "Unarchive"
			filter: do(repo) repo.archived
			call: do(repo) client.updateRepo repo, {archived: no}
		deleteRepos:
			type: "repos"
			description: "Delete"
			filter: do(repo) !repo.disabled
			call: do(repo) client.deleteRepo repo
		deleteGists:
			type: "gists"
			description: "Delete"
			filter: do(gist) yes
			call: do(gist) client.deleteGist
	}

	type = "repos"
	token = ""
	visibility = "all"
	affiliation = "owner"
	sort = "full_name"
	direction = "asc"
	page = 1
	perPage = 10
	
	repos = []
	checkedRepos = new Map
	gists = []
	checkedGists = new Map
	action = ""
	showModal = no
	progressBarValue = 0
	progressBarMax = 0
	showProgressBar = no
	client = null

	get showRepos
		type === "repos"

	def setup
		const tokenFromStorage = window.localStorage.getItem "token"
		if tokenFromStorage
			token = tokenFromStorage;
	
	def sleep time
		new Promise do(resolve, reject)
			setTimeout(resolve, time)

	def submit
		window.localStorage.setItem "token", token
		client = GithubClient.withToken token
		if showRepos
			const response = await client.getRepos {
				visibility
				affiliation
				sort
				direction
				page
				per_page: perPage
			}
			return unless response.ok
			repos = response.repos
			pageOptions = response.pages
		else
			const response = await client.getGists {
				page
				per_page: perPage
			}
			return unless response.ok
			gists = response.gists
			pageOptions = response.pages
	
	def update
		showModal = yes
	
	def confirm
		showModal = no
		const chosenAction = actionOptions[action]
		const filtered = [
				...(showRepos ? checkedRepos : checkedGists).values()
			].filter(chosenAction.filter)
		progressBarValue = 0
		progressBarMax = filtered.length
		showProgressBar = yes
		
		for repo of filtered
			await chosenAction.call repo
			progressBarValue += 1
			imba.commit!
		
		await sleep 1000
		showProgressBar = no
		window.location.reload() # FIX
	
	def cancel
		showModal = no
	
	def toggleRepo event
		const {checked, value} = event.target
		const repoId = Number value
		const repo = repos.find do(repo) repo.id === repoId
		return unless repo
		if checked
			checkedRepos.set repo.id, repo
		else
			checkedRepos.delete repo.id
	
	def toggleGist event
		const {checked, value} = event.target
		const gist = gists.find do(gist) gist.id === value
		return unless gist
		if checked
			checkedGists.set gist.id, gist
		else
			checkedGists.delete gist.id
	
	def $filter-container
		<form>
			<fieldset[d:flex fld:row g:6]>
				<label>
					<input type="radio" name="type" value="repos" bind=type>
					"Repos"
				<label>
					<input type="radio" name="type" value="gists" bind=type>
					"Gists"

			<fieldset.grid>
				<label[gcs:1 gce:6]=!showRepos> "Token"
					<input type="password" placeholder="Token" bind=token>

				if showRepos
					<label> "Visibility"
						<select bind=visibility> for option in visibilityOptions
							<option> option

					<label> "Affiliation"
						<select bind=affiliation> for option in affiliationOptions
							<option> option

					<label> "Sort"
						<select bind=sort> for option in sortOptions
							<option> option

					<label> "Direction"
						<select bind=direction> for option in directionOptions
							<option> option
				
				<label> "Page"
					<select bind=page> for option in pageOptions
						<option> option
			
				<label> "Per page"
					<select bind=perPage> for option in perPageOptions
						<option> option

				<button type="button" @click=submit> "Filter"
	
	def $repos-container
		return unless showRepos
		<article>
			<header> "Repos"
			if repos.length == 0
				<div[ta:center]> "No repos"
			for repo in repos
				<($repo-card repo)>
		
	def $repo-card repo
		<details>
			<summary.contrast.outline role="button">
				<($repo-checkbox repo)>
				repo.full_name
			<div.capitalize> repo.visibility
			<div> "Template: {repo.is_template}"
			<div> "Archived: {repo.archived}"
			<div> "Disabled: {repo.disabled}"
			<div> "Open issues: {repo.open_issues}"
			<div> "Forks: {repo.forks}"
			<div> "Lang: {repo.language}"
			<div> "Created at: {repo.created_at}"
			<div> "Updated at: {repo.updated_at}"
			<div> <a target="_blank" href=repo.html_url> "See on Github"
	
	def $repo-checkbox repo
		const checked = checkedRepos.has repo.id
		<input type="checkbox" value=repo.id @change=toggleRepo checked=checked>

	def $gists-container
		return if showRepos
		<article>
			<header> "Gists"
			if gists.length == 0
				<div[ta:center]> "No gists"
			for gist in gists
				<($gist-card gist)>
		
	def $gist-card gist
		<details>
			<summary.contrast.outline role="button">
				<($gist-checkbox gist)>
				gist.id
			<ul> for own filename, _ of gist.files
				<li> filename
			<div> <a target="_blank" href=gist.html_url> "See on Github"
	
	def $gist-checkbox gist
		const checked = checkedGists.has gist.id
		<input type="checkbox" value=gist.id @change=toggleGist checked=checked>

	def $action-container
		const chosenAction = actionOptions[action]
		const disabled = !chosenAction or chosenAction.type !== type
		const timestamp = Date.now!
		<article>
			<header> "Action"
			<form><fieldset role="group">
				<select bind=action>
					<option value=""> "Choose an action"
					for own option, action of actionOptions when action.type === type
						<option value=option> action.description
				<button type="button" disabled=disabled @click=update> "Update"

			if showRepos
				for [key, repo] of checkedRepos
					<label key=key+timestamp>
						<($repo-checkbox repo)>
						repo.full_name
			else
				for [key, gist] of checkedGists
					<label key=key+timestamp>
						<($gist-checkbox gist)>
						gist.id
	
	def $action-modal
		return unless showModal
		const chosenAction = actionOptions[action]
		<dialog open> <article>
			<header> "Confirm action"
			"Are you sure you want to {chosenAction.description.toLowerCase!}:"
			if showRepos
				<ul> for [_, repo] of checkedRepos when chosenAction.filter repo
					<li> repo.full_name
			else
				<ul> for [_, gist] of checkedGists when chosenAction.filter gist
					<li> gist.id
			<footer>
				<button type="button" @click=confirm> "Confirm"
				<button.secondary type="button" @click=cancel> "Cancel"
	
	def $action-progress-bar
		return unless showProgressBar
		const completed = progressBarValue === progressBarMax
		<dialog open> <article>
			<header> completed ? "Completed!" : "Wait..."
			<progress value=progressBarValue max=progressBarMax>
			if completed
				"Reloading"

	def render
		<self.container[pt:2]>
			<($filter-container!)>
			<div.grid>
				<($action-container!)>
				<($repos-container!)>
				<($gists-container!)>
			<($action-modal!)>
			<($action-progress-bar!)>

imba.mount <app>, document.getElementById "app"
