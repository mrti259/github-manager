import { GithubClient } from "./github-client.imba"

tag app
	visibilityOptions = ["all", "public", "private"]
	affiliationOptions = ["owner", "collaborator", "organization_member"]
	sortOptions = ["created", "updated", "pushed", "full_name"]
	directionOptions = ["asc", "desc"]
	pageOptions = [1]
	perPageOptions = [10, 20, 50]
	actionOptions = {
		private:
			description: "Set to private"
			filter: do(repo) !repo.private
			call: do(repo) client.updateRepo(repo.full_name, {private: yes})
		public:
			description: "Set to public"
			filter: do(repo) repo.private
			call: do(repo) client.updateRepo repo.full_name, {private: no}
		archive:
			description: "Archive"
			filter: do(repo) !repo.archived
			call: do(repo) client.updateRepo repo.full_name, {archived: yes}
		delete:
			description: "Delete"
			filter: do(repo) !repo.disabled
			call: do(repo) client.deleteRepo repo.full_name
	}

	token = ""
	visibility = "all"
	affiliation = "owner"
	sort = "full_name"
	direction = "asc"
	page = 1
	perPage = 10
	
	repos = []
	checkedRepos = new Map()
	action = ""
	showModal = no
	progressBarValue = 0
	progressBarMax = 0
	showProgressBar = no
	client = null

	def setup
		const tokenFromStorage = window.localStorage.getItem "token"
		if tokenFromStorage
			token = tokenFromStorage;

	def submit
		window.localStorage.setItem "token", token
		client = GithubClient.withToken token
		const response = await client.getRepos {
			visibility
			affiliation
			sort
			direction
			page
			per_page: perPage
		}
		if !response.ok
			return
		repos = response.repos
		pageOptions = response.pages
	
	def update
		showModal = yes
	
	def confirm
		showModal = no
		const chosenAction = actionOptions[action]
		const filteredRepos = [...checkedRepos.values()].filter chosenAction.filter
		progressBarValue = 0
		progressBarMax = filteredRepos.length
		showProgressBar = yes
		
		for repo of filteredRepos
			await chosenAction.call repo
			progressBarValue++
		
		showProgressBar = no
		window.location.reload() # FIX
	
	def cancel
		showModal = no
	
	def toggleRepo event
		const {target} = event
		const repoId = Number(target.value)
		const repo = repos.find do(repo) repo.id === repoId
		if !repo
			return
		if target.checked
			checkedRepos.set repo.id, repo
		else
			checkedRepos.delete repo.id
	
	def $filter-container
		<form><fieldset.grid>
			<label> "Token"
				<input type="password" placeholder="Token" bind=token>

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
		<article>
			<header> "Repos"
			if repos.length == 0
				<div[ta:center]> "No repos"
			for repo in repos
				<($repo-container repo)>
		
	def $repo-container repo
		<details>
			<summary.contrast.outline role="button">
				<($repo-checkbox repo)>
				repo.full_name
			<div[tt:capitalize]> repo.visibility
			<div> "Template: {repo.is_template}"
			<div> "Archived: {repo.archived}"
			<div> "Disabled: {repo.disabled}"
			<div> "Open issues: {repo.open_issues}"
			<div> "Forks: {repo.forks}"
			<div> "Lang: {repo.language}"
			<div> "Created at: {repo.created_at}"
			<div> "Updated at: {repo.updated_at}"
			<div> <a href=repo.html_url> "See on Github"
	
	def $repo-checkbox repo
		const checked = checkedRepos.has repo.id
		<input type="checkbox" value=repo.id @change=toggleRepo checked=checked>

	def $action-container
		const disabled = action === ""
		<article>
			<header> "Action"
			<form><fieldset role="group">
				<select bind=action>
					<option value=""> "Choose an action"
					for own option, action of actionOptions
						<option value=option> action.description
				<button type="button" disabled=disabled @click=update> "Update"

			for [_, repo] of checkedRepos
				<div>
					<($repo-checkbox repo)>
					repo.full_name
	
	def $action-modal
		unless showModal
			return 
		const chosenAction = actionOptions[action]
		<dialog open> <article>
			<header> "Confirm action"
			"Are you sure you want to {chosenAction.description.toLowerCase!}:"
			<ul> for [_, repo] of checkedRepos when chosenAction.filter repo
				<li> repo.full_name
			<footer>
				<button type="button" @click=confirm> "Confirm"
				<button.secondary type="button" @click=cancel> "Cancel"
	
	def $action-progress-bar
		unless showProgressBar
			return 
		<dialog open> <article>
			<progress value=progressBarValue max=progressBarMax>

	def render
		<self.container[pt:2]>
			<($filter-container!)>
			<div.grid>
				<($action-container!)>
				<($repos-container!)>
			<($action-modal!)>
			<($action-progress-bar!)>

imba.mount <app>, document.getElementById "app"
