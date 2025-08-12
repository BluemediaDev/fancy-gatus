<script lang="ts">
  let props: {
    error: Error | null
    retry?: () => void
  } = $props()

  function getErrorMessage(error: Error | null): string {
    if (!error) return 'Unknown error occurred'
    
    if ('response' in error && typeof error.response === 'object' && error.response) {
      const response = error.response as { status?: number; statusText?: string }
      
      switch (response.status) {
        case 404:
          return 'Gatus API endpoint not found (404). Please check your configuration.'
        case 403:
          return 'Access forbidden (403). Please check your authentication settings.'
        case 500:
          return 'Gatus server error (500). The monitoring service may be down.'
        case 502:
        case 503:
        case 504:
          return 'Gatus service unavailable. The monitoring service may be temporarily down.'
        default:
          return `HTTP ${response.status}: ${response.statusText || 'Unknown error'}`
      }
    }
    
    if ('code' in error && typeof error.code === 'string') {
      switch (error.code) {
        case 'NETWORK_ERROR':
        case 'ERR_NETWORK':
          return 'Network error. Cannot connect to the Gatus API. Please check your network connection and Gatus URL.'
        case 'ECONNREFUSED':
          return 'Connection refused. The Gatus service may not be running or accessible.'
        case 'TIMEOUT':
          return 'Request timeout. The Gatus service is taking too long to respond.'
        default:
          return `Connection error: ${error.code}`
      }
    }
    
    return error.message || 'Failed to connect to Gatus API'
  }

  function getErrorIcon(error: Error | null): string {
    if (!error) return '❌'
    
    if ('response' in error && typeof error.response === 'object' && error.response) {
      const response = error.response as { status?: number }
      if (response.status === 404) return '🔍'
      if (response.status === 403) return '🔒'
      if (response.status && response.status >= 500) return '🚨'
    }
    
    if ('code' in error && typeof error.code === 'string') {
      if (['NETWORK_ERROR', 'ERR_NETWORK', 'ECONNREFUSED'].includes(error.code)) return '🌐'
      if (error.code === 'TIMEOUT') return '⏱️'
    }
    
    return '⚠️'
  }
</script>

<div class="alert alert-error w-full mb-10 p-0 shadow-sm">
  <div class="card-body">
    <div class="flex items-center gap-2 mb-2">
      <span class="text-2xl">{getErrorIcon(props.error)}</span>
      <h2 class="card-title">Connection Failed</h2>
    </div>
    
    <p class="text-sm opacity-90 mb-3">
      {getErrorMessage(props.error)}
    </p>
    
    <div class="text-xs opacity-75 mb-3">
      <p class="font-bold mb-2">Troubleshooting:</p>
      <ul class="list-disc list-inside space-y-1 ml-2">
        <li>Verify the Gatus base URL in your configuration</li>
        <li>Ensure the Gatus API endpoint <code>/api/v1/endpoints/statuses</code> is accessible</li>
        <li>Check if Gatus is running and healthy</li>
        <li>Verify network connectivity and firewall settings</li>
      </ul>
    </div>
    
    {#if props.retry}
      <div class="card-actions justify-end">
        <button class="btn btn-sm btn-outline" onclick={props.retry}>
          🔄 Retry Connection
        </button>
      </div>
    {/if}
  </div>
</div>

<style>
  code {
    background-color: #f3f4f6;
    padding: 0.125rem 0.25rem;
    border-radius: 0.25rem;
    font-size: 0.75rem;
  }
  
  @media (prefers-color-scheme: dark) {
    code {
      background-color: #374151;
    }
  }
</style>