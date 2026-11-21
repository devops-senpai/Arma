using System.Text.Json.Nodes;

using CrestCore.Contracts;
using CrestCore.Domain;

namespace CrestCore.Application;

internal sealed partial record SpacePayload {
    #region Actions - Reading

    /// A look's dress as every client reads it, or none when it holds a part no
    /// client reads.
    private static SpaceDress? ReadDress(JsonObject branding) {
        try {
            return StoredSessionCodec.DecodeDress(branding);
        } catch (Exception error) when (error is BrowserRuleException or InvalidOperationException) {
            return null;
        }
    }

    #endregion
}
