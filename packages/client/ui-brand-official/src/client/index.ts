/** LuWu Harness brand occupants for the generic browser-brand slots. */
import type { Context as ClientContext } from '@deepseek-ai/cordis'
import type {} from '@deepseek-ai/dsh-client-ui-renderer/client'
import type {} from '@deepseek-ai/dsh-client-ui-sidebar/client'

/** Required service: the UI slot registry. */
export const inject = ['slots']

/**
 * LWH-LOCAL PATCH (LuWu Harness): register no occupants, so both generic sidebar brand slots
 * render their own fallbacks — the LuWu Harness mark from `ui-primitives` and the product name
 * from the locale dictionary (`brand.localBuild`). The upstream occupants rendered the DeepSeek
 * wordmark artwork; leaving the slots empty is what removes it. Restore the body below to go back
 * to the upstream official artwork:
 *
 *   ctx.slots.inject('sidebar.brand.mark', () =>
 *     ctx.slots.inject('sidebar.brand.name', function* () {
 *       yield ctx.slots.register({ name: 'sidebar.brand.mark' }, OfficialBrandMark)
 *       yield ctx.slots.register({ name: 'sidebar.brand.name' }, OfficialBrandName)
 *     }))
 * @param _ctx - Client root context; unused while the slots stay on their fallbacks.
 */
export function apply(_ctx: ClientContext): void {}
