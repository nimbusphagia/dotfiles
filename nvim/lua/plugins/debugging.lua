return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- -----------------------------
      -- DAP UI setup
      -- -----------------------------
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = dapui.open
      dap.listeners.before.event_terminated["dapui_config"] = dapui.close
      dap.listeners.before.event_exited["dapui_config"] = dapui.close

      -- -----------------------------
      -- Manual JS/TS adapter
      -- -----------------------------
      dap.adapters["pwa-node"] = {
        type = "server",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            os.getenv("HOME") .. "/dev/tools/vscode-js-debug/out/src/vsDebugServer.js",
            "${port}",
          },
        },
      }

      -- -----------------------------
      -- Configurations for JS/TS
      -- -----------------------------
      for _, lang in ipairs({ "javascript", "typescript" }) do
        dap.configurations[lang] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
          },
        }
      end

      -- -----------------------------
      -- Keymaps
      -- -----------------------------
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, opts)
      vim.keymap.set("n", "<leader>dc", dap.continue, opts)
      vim.keymap.set("n", "<leader>ds", dap.step_over, opts)
      vim.keymap.set("n", "<leader>di", dap.step_into, opts)
      vim.keymap.set("n", "<leader>du", dap.step_out, opts)
      vim.keymap.set("n", "<leader>do", dapui.open, opts)
      vim.keymap.set("n", "<leader>dq", dapui.close, opts)
      vim.keymap.set("n", "<leader>dr", dap.repl.open, opts)
    end,
  },
}

