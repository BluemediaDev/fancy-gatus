<script lang="ts">
  import type { Status } from '$lib/types/api'
  import type { Config } from '$lib/types/config'

  let props: {
    status: Status
    config?: Config
  } = $props()

  let isFailed = $derived(!props.status.results[props.status.results.length - 1].success)
</script>

<li
  class="list-row w-full flex flex-col lg:flex-row lg:items-center justify-center lg:justify-start"
>
  <p>
    <span class="font-semibold">{props.status.name}</span>
    {#if !props.config?.hideUrls && props.status.results[props.status.results.length - 1].hostname}
      | {props.status.results[props.status.results.length - 1].hostname}
    {/if}
  </p>
  <span class="hidden lg:flex grow"></span>
  <div class="h-full w-fit mr-8 flex flex-row justify-between items-center gap-1">
    {#each props.status.results as result (result.timestamp)}
      <div class="h-fit w-fit lg:tooltip">
        <div class="tooltip-content hidden lg:flex flex-col items-center">
          <p>{new Date(result.timestamp).toLocaleString()}</p>
          {#if result.success}
            <p class="text-success">Operational</p>
          {:else}
            <p class="text-warning">Service Problem</p>
          {/if}
        </div>
        <div
          class={['w-2', 'h-5', 'rounded-sm', result.success ? 'bg-success' : 'bg-warning']}
        ></div>
      </div>
    {/each}
  </div>
  <div class="w-35 flex flex-row items-center">
    <div class="inline-grid *:[grid-area:1/1]">
      <div
        class={[
          'status',
          'status-md',
          'animate-ping',
          isFailed ? 'status-warning' : 'status-success',
        ]}
      ></div>
      <div class={['status', 'status-md', isFailed ? 'status-warning' : 'status-success']}></div>
    </div>
    {#if isFailed}
      <p class="ml-2 text-md text-warning">Service Problem</p>
    {:else}
      <p class="ml-2 text-md text-success">Operational</p>
    {/if}
  </div>
</li>
