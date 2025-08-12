<script lang="ts">
  import type { Status as StatusType } from '$lib/types/api'
  import type { Config } from '$lib/types/config'
  import Status from '$lib/components/Status.svelte'

  let props: {
    title: string
    statuses: StatusType[]
    expandByDefault?: boolean
    config?: Config
  } = $props()

  let hasFailedStatuses = $derived.by(() => {
    return (
      props.statuses.filter((status) => {
        return !status.results[status.results.length - 1].success
      }).length > 0
    )
  })

  let expanded = $derived(hasFailedStatuses || props.expandByDefault)
</script>

<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
<div tabindex="0" class="collapse collapse-plus mb-5 bg-base-100 border-base-300 border">
  <input type="checkbox" checked={expanded} />
  <div class="collapse-title font-semibold">
    {props.title}
  </div>
  <div class="collapse-content flex flex-col">
    <ul class="list w-full">
      {#each props.statuses as status (status.key)}
        <Status {status} config={props.config} />
      {/each}
    </ul>
  </div>
</div>
