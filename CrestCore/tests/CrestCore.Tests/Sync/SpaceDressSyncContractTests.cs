using System.Text.Json.Nodes;

using CrestCore.Application;
using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// A Space's dress and dark look travel in its record beside its branding,
/// in both forms and through a merge, and a dress an older Arma wrote as keys
/// of the branding still reads.
public sealed partial class BrowserContractsTests {
    #region Actions - Tests

    [Fact]
    public void ASpacesDressAndDarkLookTravelWithItsBrandingInBothForms() {
        var (_, _, value) = CodecValue("space");
        var scheme = SpaceScheme.LatteMocha;
        value["branding"] = StoredSessionCodec.Encode(scheme.Look);
        value[StoredSessionCodec.DressKey.DarkBranding] = StoredSessionCodec.Encode(scheme.DarkLook!);

        var cloud = SyncRecordBody.Read(CodecBody("space", value), isTombstone: false, SyncPayloadForm.Journal)
            .Write(SyncPayloadForm.Cloud);
        var synced = Assert.IsType<SpacePayload>(
            SyncRecordBody.Read(Bytes(cloud), isTombstone: false, SyncPayloadForm.Cloud).Payload);

        Assert.Equal(scheme.Look, synced.Branding);
        Assert.Equal(scheme.DarkLook, synced.DarkBranding);
    }

    [Fact]
    public void ADressAnOlderArmaSyncedAsBrandingKeysStillReads() {
        var (_, _, value) = CodecValue("space");
        var branding = value["branding"]!.AsObject();
        var sky = new BrandColor(0.016, 0.647, 0.898);
        branding["folderColor"] = StoredSessionCodec.Encode(sky);
        branding["sidebarSecondaryTextColor"] = StoredSessionCodec.Encode(sky);
        branding["popoverBackgroundColor"] = StoredSessionCodec.Encode(sky);
        // A part no client reads leaves the dress, not the record.
        branding["controlsFillColor"] = "not a color";

        var payload = Assert.IsType<SpacePayload>(
            SyncRecordBody.Read(CodecBody("space", value), isTombstone: false, SyncPayloadForm.Journal).Payload);

        Assert.Equal(sky, payload.Branding.Dress?.Folders?.Color);
        Assert.Equal(sky, payload.Branding.Dress?.Text?.SecondaryColor);
        Assert.Equal(sky, payload.Branding.Dress?.Popovers?.BackgroundColor);
    }

    /// One device gives a Space a dark look and a dress while another adds a
    /// tab to it: the look follows the branding's record, and both survive.
    [Fact]
    public void ADarkLookMadeOnOneDeviceAndATabAddedOnAnotherBothSurvive() {
        var baseline = OneSpaceSession();
        var mac = new JournalUnderTest(Fixed(1_212));
        var phone = new JournalUnderTest(Fixed(1_213));
        mac.Stage(baseline);
        phone.Merge(mac.Records);
        mac.MarkUploaded();
        var scheme = SpaceScheme.ArcSky;
        var macEdit = baseline.DeepClone().AsObject();
        FirstSpace(macEdit)["branding"] = StoredSessionCodec.Encode(scheme.Look);
        FirstSpace(macEdit)[StoredSessionCodec.DressKey.DarkBranding] = StoredSessionCodec.Encode(scheme.DarkLook!);
        mac.Stage(macEdit, at: 200);
        var phoneEdit = baseline.DeepClone().AsObject();
        var added = Fixed(1_214);
        FirstSpace(phoneEdit)["tabs"]!.AsArray().Add(TabOf(added, "Cloud page", "http://localhost:3000"));
        phone.Stage(phoneEdit, at: 200);

        var (macRecords, phoneRecords) = (mac.Records, phone.Records);
        mac.Merge(phoneRecords);
        phone.Merge(macRecords);

        AssertSameRecords(mac, phone);
        var reconciled = FirstSpace(phone.Materialize(baseline));
        Assert.Equal(scheme.Look, StoredSessionCodec.DecodeBranding(reconciled["branding"]));
        Assert.Equal(scheme.DarkLook, StoredSessionCodec.DecodeBranding(reconciled[StoredSessionCodec.DressKey.DarkBranding]));
        Assert.Contains(added, Ids(reconciled["tabs"]));
    }

    #endregion
}
