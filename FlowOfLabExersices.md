# Open Topics for Labs on Hands on Day of Summit Connecct Darmstadt
## Participant count
We need to know how much people we need to calculate for. Then order a lab environment well in advance of the event.
## We need to fix oder of Labs
Option one:
- create image mode container image
   - option: Booten des containers als container! (Artikel von Armin).   << cooler usecase 
- convert container image into qcow2 image
- deploy image mode VM 
      konvertieren in qcow bootable image
As second exersize:
- update image mode VM (second).   <<< cooler usecase
      VORBEREITETE Image-mode VM bereitstellem so dasss step 2 nicht von step 1 abhängt
    kann auch leicht ein role-back <<<< ebenfalls cooler usecase
downside: update is the "cool" usecase. We should show that first.

Option two:
- update image mode VM (first)
- create image mode VM (second)
  - option: Booten des bootable containers als container! (Artikel von Armin))
downside: a image mode vm needs to be prepared before hand
  => maybe sth Aina can do?

DECISSION:
* we stick to the flow of option one! But we also prepare an image mode VM, similar to the one to create in exersize one. This enables people to do exersice 2, even if sth. went wrong with first exersize.

### Ferodra Hummingbird  (nachgelagert realisieren!)
Currently LAb relies on RH images 
