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
	
	def updateRepo fullName, options
		const response = await _request "PATCH", "repos/{fullName}", JSON.stringify(options)
	
	def deleteRepo fullName
		const response = await _request "DELETE", "repos/{fullName}"
	
	def _getPages page, response
		const linkHeader = response.headers.get("link") || ""
		const pages = [page]
		for link in linkHeader.split ","
			const match = link.match /page=(\d+)/
			if !match
				continue
			const newPage = Number match[1]
			if pages.includes newPage
				continue
			pages.push newPage
		pages.sort!
	
	def _request method, path, body
		const headers = {
			"Accept": "application/vnd.github+json"
			"X-GitHub-Api-Version": "2022-11-28"
			"Authorization": "Bearer {_token}"
		}
		const url = "https://api.github.com/{path}"
		window.fetch(url, {method, headers, body})
