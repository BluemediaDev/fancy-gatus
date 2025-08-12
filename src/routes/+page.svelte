<script lang="ts">
  import axios from 'axios'
  import type { AxiosError } from 'axios'
  import { onMount } from 'svelte'
  import type { Config } from '$lib/types/config'
  import type { Status } from '$lib/types/api'
  import Loader from '$lib/components/Loader.svelte'
  import Header from '$lib/components/Header.svelte'
  import Notice from '$lib/components/Notice.svelte'
  import OverallStatus from '$lib/components/OverallStatus.svelte'
  import EndpointGroup from '$lib/components/StatusGroup.svelte'
  import RefreshSettings from '$lib/components/RefreshSettings.svelte'
  import Footer from '$lib/components/Footer.svelte'
  import ErrorDisplay from '$lib/components/ErrorDisplay.svelte'

  let loading = $state(true)
  let error: Error | null = $state(null)
  let config: Config = $state({})
  let apiData: Status[] = $state([])

  async function getConfig() {
    try {
      const response = await axios.get('config.json', {
        baseURL: '/',
        timeout: 10000 // 10 second timeout
      })

      config = response.data
      // Set title if defined in config
      if (config.title) {
        document.title = config.title
      }
    } catch (err) {
      const error = err as AxiosError
      if (error.response && error.response.status === 404) {
        console.warn('No config.json file found. Using default values.')
      } else {
        console.warn('Error getting config:', error.message)
      }
      // Don't set error state for config failures, just use defaults
    }
  }

  async function getApiData() {
    // Set base URL for API calls if defined in config
    if (config.gatusBaseUrl && axios.defaults.baseURL !== config.gatusBaseUrl) {
      axios.defaults.baseURL = config.gatusBaseUrl
    }

    try {
      error = null // Clear any previous errors
      const response = await axios.get('/api/v1/endpoints/statuses', {
        timeout: 15000 // 15 second timeout for API calls
      })
      apiData = response.data
      loading = false
    } catch (err) {
      const axiosError = err as AxiosError
      error = axiosError
      loading = false
      console.error('Failed to fetch API data:', axiosError)
      
      // Log detailed error information for debugging
      if (axiosError.response) {
        console.error('Response error:', {
          status: axiosError.response.status,
          statusText: axiosError.response.statusText,
          data: axiosError.response.data
        })
      } else if (axiosError.request) {
        console.error('Request error - no response received:', {
          url: axiosError.config?.url,
          baseURL: axiosError.config?.baseURL,
          timeout: axiosError.config?.timeout
        })
      } else {
        console.error('Error:', axiosError.message)
      }
    }
  }

  async function refresh() {
    loading = true
    error = null
    await getConfig()
    await getApiData()
  }

  function retryConnection() {
    refresh()
  }

  // Group statuses by their group name
  // and sort them according to the config if specified
  let groups: { title: string; statuses: Status[] }[] = $derived.by(() => {
    // Group statuses by group name
    let groups: Map<string, Status[]> = new Map<string, Status[]>()
    apiData.map((status) => {
      // Filter statuses that should be hidden
      if (config.hiddenStatuses?.includes(status.name)) return
      if (!status.group) {
        status.group = 'Ungrouped'
      }
      // Filter groups that should be hidden
      if (config.hiddenGroups?.includes(status.group)) return
      let groupStatuses = groups.get(status.group) || []
      groupStatuses.push(status)
      groups.set(status.group, groupStatuses)
    })

    // Sort by config
    let tmp = groups
    let sortedGroups: { title: string; statuses: Status[] }[] = []
    if (config.groupOrder) {
      config.groupOrder.forEach((key) => {
        if (tmp.has(key)) {
          sortedGroups.push({ title: key, statuses: tmp.get(key)! })
          tmp.delete(key)
        }
      })
    }

    // Sort remaining group alphabetically
    let sortedKeys = [...tmp.keys()].sort((a, b) => a.localeCompare(b))
    sortedKeys.map((key) => {
      let statuses = tmp.get(key)!
      sortedGroups.push({ title: key, statuses })
    })
    return sortedGroups
  })

  // Array of statuses where the last result has success = false
  let failedStatuses = $derived.by(() => {
    const filteredStatuses = groups.flatMap((item) => item.statuses)
    return filteredStatuses.filter((status) => {
      return !status.results[status.results.length - 1].success
    })
  })

  onMount(() => {
    refresh()
  })
</script>

{#if loading}
  <Loader />
{:else if error}
  <Header title={config.title} />
  {#if config.notice}
    <Notice notice={config.notice} />
  {/if}
  <ErrorDisplay {error} retry={retryConnection} />
  <RefreshSettings defaultRefreshInterval={config.defaultRefreshInterval} onRefresh={refresh} />
  {#if !config.hideFooter}
    <Footer />
  {/if}
{:else}
  <Header title={config.title} />
  {#if config.notice}
    <Notice notice={config.notice} />
  {/if}
  <OverallStatus {failedStatuses} />
  {#each groups as group (group.title)}
    <EndpointGroup
      title={group.title}
      statuses={group.statuses}
      expandByDefault={config.defaultExpandGroups}
      {config}
    />
  {/each}
  <RefreshSettings defaultRefreshInterval={config.defaultRefreshInterval} onRefresh={refresh} />
  {#if !config.hideFooter}
    <Footer />
  {/if}
{/if}
