export class GithubClient
	static def withToken token
		new this token
	
	def constructor token
		_token = token
	
	def getRepos options
		const query = new URLSearchParams options
		const response = await _request "GET", "user/repos?{query}"
		const ok = response.ok
		const repos = await response.json!
		const pages = _getPages options.page, response
		return {ok, repos, pages}
	
	def updateRepo repo, options
		const response = await _request "PATCH", "repos/{repo.full_name}", JSON.stringify(options)
	
	def deleteRepo repo
		const response = await _request "DELETE", "repos/{repo.full_name}"
	
	def getGists options
		const query = new URLSearchParams options
		const response = await _request "GET", "gists?{query}"
		const ok = response.ok
		const gists = await response.json!
		const pages = _getPages options.page, response
		return {ok, gists, pages}
	
	def deleteGist gist
		const response = await _request "DELETE", "gists/{gist.id}"
	
	def _getPages page, response
		const linkHeader = response.headers.get("link") || ""
		const pages = [page]
		for link in linkHeader.split ","
			const match = link.match /page=(\d+)/
			continue unless match
			const newPage = Number match[1]
			continue if pages.includes newPage
			pages.push newPage
		pages.sort!
	
	def _request method, path, body=undefined
		const headers = {
			"Accept": "application/vnd.github+json"
			"X-GitHub-Api-Version": "2022-11-28"
			"Authorization": "Bearer {_token}"
		}
		const url = "https://api.github.com/{path}"
		window.fetch(url, {method, headers, body})
