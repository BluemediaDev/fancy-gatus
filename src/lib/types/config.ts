export type Notice = {
  type?: 'success' | 'warning' | 'error'
  title: string
  content: string
  createdAt: string
  updatedAt?: string
}

export type Config = {
  title?: string
  gatusBaseUrl?: string
  hiddenGroups?: string[]
  hiddenStatuses?: string[]
  groupOrder?: string[]
  defaultExpandGroups?: boolean
  defaultRefreshInterval?: 10 | 30 | 60 | 120 | 300 | 600
  hideUrls?: boolean
  hideFooter?: boolean
  notice?: Notice
}
