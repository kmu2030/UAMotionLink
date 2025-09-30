# UAMotionLinkLib
**UAMotionLinkLib** is a library that provides an external motion control interface for OMRON's NX/NJ controllers.
It makes motion function blocks (motion FBs) available via a wrapper on the controller's or simulator's OPC UA server, allowing motion control through an OPC UA client.
**UAMotionLinkLib** exposes motion FB operations as a pseudo-UA method, as demonstrated in [PseudoUAMethodExample](https://www.google.com/search?q=https://github.com/kmu2030/PseudoUAMethodExample).
It also includes a reference client (**SingleMCController**) and tests that use [PwshOpcUaClient](https://www.google.com/search?q=https://github.com/kmu2030/PwshOpcUaClient).

Currently, the exposed motion FBs are limited to basic positioning operations.
Operations such as servo power control (`MC_Power`), controlled stop (`MC_Stop`), and immediate stop (`MC_ImmediateStop`) are not provided.
Continuous, synchronized, or multi-axis coordinated motion is also not included.
Users can easily extend the functionality.
If any functions are missing, users can extend them at their own discretion.

UAMotionLink offers the following operations:

  * **MoveAbsolute**   
    Performs absolute positioning for the target axis.
    Parameters are the same as `MC_MoveAbsolute`.
  * **MoveRelative**   
    Performs relative positioning for the target axis.
    Parameters are the same as `MC_MoveRelative`.
  * **MoveZeroPosition**   
    Returns the target axis to its home position.
    Parameters are the same as `MC_MoveZeroPosition`.
  * **Home**   
    Defines the home position for the target axis.
    Parameters are the same as `MC_Home`.
  * **SetPosition**   
    Changes the current command position and feedback position of the target axis to an arbitrary value.
    Parameters are the same as `MC_SetPosition`.
  * **ResetAxisError**   
    Resets an error on the target axis.
    This is a wrapper for `MC_Reset`.
  * **SetAxisIndex**   
    Specifies the target axis by its index.
  * **AxisIndex**   
    Retrieves the index of the currently targeted axis.
  * **Axis**   
    Retrieves the `_sAXIS_REF` structure of the target axis.

The reference client provides the functionality to perform the operations listed above. While humans can use it without issue, it was developed with the primary purpose of being used by AI shells, chat AI, or AI agents, so it may be verbose. There are currently no plans to create an MCP server.

## Operating Environment
The following are required to use the `UAMotionLinkLib` library:

| Item | Requirement |
| :--- | :--- |
| Controller | NX1 (Ver. 1.64 or later), NX5 (Ver. 1.64 or later), NX7 (Ver. 1.35 or later), NJ5 (Ver. 1.63 or later) |
| Sysmac Studio | Ver. 1.62 or later |

The following is required to use the `SingleMCController` reference client:

| Item | Requirement |
| :--- | :--- |
| PowerShell | 7.5 or later |

## Development Environment
UAMotionLinkLib and SingleMCController were built in the following environment:

| Item | Version |
| :--- | :--- |
| Controller | NX102-9000 Ver. 1.64 HW Rev.A |
| Sysmac Studio | Ver. 1.63 |
| PowerShell | 7.5.2 |
| Pester | 5.7.1 |

## Library Structure
UAMotionLinkLib consists of the following:

  * **UAMotionLinkLib.slr**   
    A library for Sysmac projects. It is used by referencing it in a project.

  * **UAMotionLinkLib.smc2**   
    A Sysmac project for UAMotionLinkLib development. It includes test programs for the reference client.

## How to Use the Library
Follow these steps to use the library:

1.  **Reference UAMotionLinkLib.slr in your project.**

2.  **Build the project and confirm there are no errors.**   
    This verifies that there are no identifier conflicts within the project.

3.  **Execute the BasicMCControllerModel FB (model FB) in an appropriate program POU.**   
    Because it contains motion FBs, the program POU must be executed in the primary task.

4.  **Expose the model FB in the OPC UA settings.**   
    Refer to the manufacturer's manual for instructions on exposing FB instances.
    Assign appropriate user roles to each method.

## Reference Client Structure
The main components of the reference client are:

  * **BasicMCController.ps1**   
    The reference client itself.

  * **BasicMCController.Tests.ps1**   
    Tests for the reference client and model using `Pester` and `UAMotionLinkLib.smc2`.

  * **ModelTestController.ps1**   
    Operates the test program running in `UAMotionLinkLib.smc2`.

  * **SingleMCController.ps1**   
    Defines a derived class of BasicMCController, intended for use by an AI agent.

  * **SingleMCController.psm1**   
    The module for the reference client. This file must be imported to use the reference client.

  * **PwshOpcUaClient/**   
    This is the PwshOpcUaClient. For usage, refer to [PwshOpcUaClient](https://www.google.com/search?q=https://github.com/kmu2030/PwshOpcUaClient).

## How to Use the Reference Client
The reference client is used for testing and demonstration.
The general steps are:

1.  **Import SingleMCController.psm1.**

2.  **Execute the code that uses the reference client.**

Upon the first connection to an OPC UA server with security enabled, the connection may fail.
This is because the OPC UA server rejects the client certificate from PwshOpcUaClient.
If this occurs, you can allow the client certificate on the OPC UA server to prevent it from being rejected in the future.

## Examples
Examples are located in the `examples\` directory. For details, refer to each directory.

  * **ControlWithAIShell**   
    Uses [AI Shell](https://learn.microsoft.com/en-us/powershell/utility-modules/aishell/overview?view=ps-modules) as an intermediary to control servos via a chat AI or to collaborate with one.
    You can control a servo via AI Shell as shown below.

    ![Servo Operation via AI Shell](./images/control-with-ai-shell.gif)

## License
Code using **PwshOpcUaClient** is licensed under GPLv2.
All other code is licensed under the MIT License.
