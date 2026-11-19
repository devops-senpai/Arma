using System.Text.Json.Nodes;

using CrestCore.Application;
using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// Setup as the core walks a person through it: where each entry opens and
/// where Back and Next lead on each platform, the queue of browsers it imports
/// in turn, finishing, which applies the manual setup and opens the Getting
/// Started guide only in an unlocked first Space, and whether the device has
/// completed setup, which the device store adopts once and keeps.
public sealed partial class BrowserContractsTests {
    [Fact]
    public void AFirstLaunchsSpaceAndANewSpaceOfASetupStartWithAFavoritesFolderEveryPreviewAndTheAppliedSetupHold() {
        var session = SavedSession().Document["session"]!;
        using var device = new TestDevice(session);
        device.Send(new StartSetup(device.Workspace, SetupEntry.ManualSetup));
        device.Send(new AddSetupSpace());
        var setup = new ApplyManualSetup(device.Workspace, Guid.NewGuid());
        // The first launch's Space keeps the folders it had; the one setup gives it comes after them.
        static FolderState[] Folders(IReadOnlyList<SpaceState> spaces) =>
            [.. spaces.Select(space => Assert.Single(space.Folders, folder => folder.Title == SetupDraft.NewSpaceFolderTitle))];
        var folders = Folders(device.Query(new ImportPreview(setup)).Session.Spaces);
        Assert.Equal(2, folders.Length);
        Assert.All(folders, folder => Assert.Equal((TabPlacement.Saved, SetupDraft.NewSpaceFolderTitle, (Guid?)null),
            (folder.Location, folder.Title, folder.ParentId)));
        Assert.NotEqual(folders[0].Id, folders[1].Id);
        // Each folder keeps its identity from one preview to the next, as the Space does, so setup's
        // live copy of the browser goes on showing it instead of opening again on every change.
        Assert.Equal(folders, Folders(device.Query(new ImportPreview(setup)).Session.Spaces));
        device.Send(setup);
        Assert.Equal(folders, Folders(device.Authority.Current.Spaces));
    }

    [Fact]
    public void CompletionIsAdoptedOnceAndKeptInTheDeviceStore() {
        using var directory = new StorageDirectory();
        var document = SavedSession().Document["session"]!.AsObject();
        var configuration = new AppConfiguration(directory.Path, DevicePlatform.Desktop);
        Guid first = SpaceId(document["spaces"]![0]!);
        using (var app = new CrestApp(configuration)) {
            app.Send(Adoption(document));
            var workspace = TestWorkspaces.OpenStored(app).Workspace;
            Assert.Contains(new SetupCompletedChanged(false), app.Send(new AdoptSetupCompletion(Completed: false)));
            var fresh = Flowing(app.Send(new StartSetup(workspace, SetupEntry.FirstRun)));
            Assert.Equal((true, false), (fresh.OpensGuide, fresh.OpensCrestFromWelcome));
            var finished = app.Send(new FinishSetup(Guid.NewGuid()));
            Assert.Contains(new SetupCompletedChanged(true), finished);
            Assert.Contains(new SetupFinished(workspace, first), finished);
        }
        using (var app = new CrestApp(configuration)) {
            var workspace = TestWorkspaces.OpenStored(app).Workspace;
            // The store adopted once: what an installed release kept no longer counts.
            Assert.Contains(new SetupCompletedChanged(true), app.Send(new AdoptSetupCompletion(Completed: false)));
            var again = Flowing(app.Send(new StartSetup(workspace, SetupEntry.FirstRun)));
            Assert.Equal((false, true), (again.OpensGuide, again.OpensCrestFromWelcome));
            Assert.True(Flowing(app.Send(new StartSetup(workspace, SetupEntry.Rerun))).OpensGuide);
        }
        using var adopting = new StorageDirectory();
        using (var app = new CrestApp(new AppConfiguration(adopting.Path, DevicePlatform.Desktop))) {
            app.Send(Adoption(document));
            Assert.Contains(new SetupCompletedChanged(true), app.Send(new AdoptSetupCompletion(Completed: true)));
        }
        using var reopened = new CrestApp(new AppConfiguration(adopting.Path, DevicePlatform.Desktop));
        Assert.Contains(new SetupCompletedChanged(true), reopened.Send(new AdoptSetupCompletion(Completed: false)));
    }
}
